class StoreController < ApplicationController
  layout 'main'
  include OrderHelper
  include Pagination
  include ActiveMerchant::Billing::Integrations

  before_filter :find_cart, :find_customer
  
  before_filter :find_order_and_redirect_if_nil,
    :only => [
      :select_shipping_method, :view_shipping_method, :set_shipping_method,
      :confirm_order, :finish_order
    ]

  before_filter :ssl_required,
    :only => [
      :checkout, :select_shipping_method, :view_shipping_method,
      :set_shipping_method, :confirm_order, :finish_order
    ]
  

  if Preference.find_by_name('store_test_transactions').is_true?
    ActiveMerchant::Billing::Base.integration_mode = :test 
  else
    ActiveMerchant::Billing::Base.integration_mode = :production
  end

  # You can change this in an override depending on how many steps you want.
  #
  # For instance, perhaps you want to skip shipping calculation.
  #
  # If so, in your overidden controller (in /app/controllers/store_controller.rb)
  # You could set this to be:
  #   @@action_after_checkout = 'finish_order'
  @@action_after_checkout = 'select_shipping_method'

  # Our simple store index
  def index
    @title = "Store"
		@tags = Tag.find_alpha
		@tag_names = nil
		@viewing_tags = nil

    @products = Product.paginate(
      :order => 'name ASC',
      :conditions => Product::CONDITIONS_AVAILABLE,
      :page => params[:page],
      :per_page => 10
    )
  end
  
  def search
    @search_term = params[:search_term]
    @title = "Search Results for: #{@search_term}"
    @products = Product.paginate(
      :order => 'name ASC',
      :conditions => ["(name LIKE ? OR code = ?) AND #{Product::CONDITIONS_AVAILABLE}", "%#{@search_term}%", @search_term],
      :page => params[:page],
      :per_page => 10
    )
    # If only one product comes back, take em directly to it.
    if @products.size == 1
      redirect_to :action => 'show', :id => @products[0].code and return
    else
      render :action => 'index'
    end
  end

	# Shows products by tag or tags.
	# Tags are passed in as id #'s separated by commas.
	#
	def show_by_tags
		# Tags are passed in as an array.
		# Passed into this controller like this:
		# /store/show_by_tags/tag_one/tag_two/tag_three/...
		@tag_names = params[:tags]
		# Generate tag ID list from names
		tag_ids_array = Array.new
		for name in @tag_names
			temp_tag = Tag.find_by_name(name)
			if temp_tag then
				tag_ids_array << temp_tag.id
			end
		end
		@viewing_tags = Tag.find(tag_ids_array)
		viewing_tag_names = @viewing_tags.collect { |t| " > #{t.name}"}
		@title = "Store #{viewing_tag_names}"
		@tags = Tag.find_related_tags(tag_ids_array)
		
		# Paginate products so we don't have a ton of ugly SQL
		# and conditions in the controller		
		per_page = 10
    list = Product.find_by_tags(tag_ids_array, true)
    pager = Paginator.new(list, list.size, per_page, params[:page])
    @products = returning WillPaginate::Collection.new(params[:page] || 1, per_page, list.size) do |p|
      p.replace list[pager.current.offset, pager.items_per_page]
    end
		
		render :action => 'index'
	end

  def show
    @product = Product.find_by_code(params[:id])
    if !@product
      flash[:notice] = "Sorry, we couldn't find the product you were looking for"
      redirect_to :action => 'index' and return false
    end
    @title = @product.name
    @images = @product.images.find(:all)
    @default_image = @images[0]
    @full_product_name = @product.manufacturers[0].name + ' ' + @product.name
    @variations = @product.variations.find(
      :all, 
      :order => 'name ASC',
      :conditions => 'quantity > 0'
    )
  end
  
  # Shows shopping cart in pop-up window.
  #
  def show_cart
    sanitize!
    render :layout => 'modal' and return
  end


	# Adds an item to our cart via AJAX
	#
	# Returns the cart HTML as a partial to update the view in JS
	def add_to_cart_ajax
	  sanitize!
	  # If variations are present we get that as the ID instead...
	  if params[:variation]
	    product = Variation.find(params[:variation])
	  else
		  product = Product.find(params[:id])
		end
		quantity = params[:quantity]
		quantity ||= 1
		
		logger.info "QUANTITY: #{quantity}"
	  logger.info "PRODUCT QUANTITY: #{product.quantity}"
	  logger.info "Quantity too much? #{(quantity.to_i > product.quantity.to_i)}"
	  
		# Checks quantity against available.
		if quantity.to_i > product.quantity.to_i
		  logger.info "There's an error adding to the cart..."
		  render :nothing => true, :status => 400 and return
		else
  		@cart.add_product(product, quantity.to_i)
  		logger.info "Product added...success"
  		render :partial => 'cart' and return
  	end
	end


	# Removes one item via AJAX
	#
	# Returns the cart HTML as a partial to update the view in JS
	def remove_from_cart_ajax
		product = Item.find(params[:id])
		@cart.remove_product(product)
		render :partial => 'cart'
	rescue
		render :text => "There was a problem removing that item. Please refresh this page."
	end

	# Empties the entire cart via ajax...
	#
	# Again, returns cart HTML via partial
	def empty_cart_ajax
		clear_cart_and_order
		render :partial => 'cart'
	end

  # Empties the cart out and redirects to index.
  # Removes any order saved to the DB if there is such a thing.
  #
  # The old (non-ajax) way of doing things
  def empty_cart
    clear_cart_and_order
    redirect_to_index("All items have been removed from your order.")
  end

  # Gathers customer information.
  # Displays form fields for grabbing name/addy/credit info
  #
  # Also displays items in the current order
  def checkout
    @title = "Please enter your information to continue this purchase."
    @items = @cart.items
    @order = find_order
    @cc_processor = Order.get_cc_processor
    if request.get?
      if @order == nil then
        # Save standard form info
        logger.info("\n\nNEW ORDER INIT\n\n")
        initialize_new_order
      else
        logger.info("\n\nEXISTING ORDER INIT\n\n")
        initialize_existing_order
      end
      if @items.empty?
        redirect_to_index("You've not chosen to buy any items yet. Please select an item from this page.")
      end
    elsif request.post?
      # Turned into a private method now so we don't have checkout/do_checkout...
      do_checkout()
    end
  end

  # Checks shipping price of items
  # Used with live rate calculation
  # Lets customer choose what method to use
  def select_shipping_method
    @title = "Select Your Shipping Method - Step 2 of 3"

    if @order == nil then
      redirect_to_checkout("Have you entered all of this information yet?") and return
    end
    
    if (Substruct.use_live_rate_calculation == true) then
    end
    
    @items = @order.order_line_items
    session[:order_shipping_types] = @order.get_shipping_prices
    # Set default price to pick what radio button should be entered
    @default_price = session[:order_shipping_types][0].id if session[:order_shipping_types][0]
  end

  # Execution action of select_shipping_method (above)
  # OR called when setting shipping method using a flat calculation...
  #
  # Saves shipping method, redirects to order review page.
  #
  def set_shipping_method
    ship_id = params[:ship_type_id]
    # Convert to integers for comparison purposes!
    ship_type = session[:order_shipping_types].find { |type| type.id.to_i == ship_id.to_i }
    ship_price = ship_type.calculated_price
    @order.order_shipping_type_id = ship_id
    @order.shipping_cost = ship_price
    @order.save
    
    if Preference.find_by_name('store_show_confirmation').is_true?
      action_after_shipping = 'confirm_order'
    else
      action_after_shipping = 'finish_order'
    end
    redirect_to :action => action_after_shipping
  end

  # This page only exists so the user may confirm their order.
  #
  # They are presented with options to cancel and start over, 
  # or process their order.
  #
  def confirm_order
    @title = "Please confirm your order. - Step 3 of 3"
    @cc_login = Order.get_cc_login 
    @paypal_url = Paypal.service_url
    # Make sure a shipping method is set
    if @order.order_shipping_type_id == nil
      redirect_to_shipping and return
    end
  end

  # Finishes the order
  #
  # Submits order info to Authorize.net
  def finish_order
    @title = "Thanks for your order!"
    cc_processor = Order.get_cc_processor
    order_success = @order.run_transaction
    if order_success == true
      @payment_message = "Card processed successfully"
      clear_cart_and_order(false)
    elsif cc_processor == Preference::CC_PROCESSORS[1]
      case order_success
        when 4
          @payment_message = %q\
            Your order has been processed at PayPal but we
	          have not heard back from them yet.  Your order
			      will be ready to ship as soon as we receive 
			      confirmation of your payment.
			    \
	        clear_cart_and_order(false)
	      when 5
	        @payment_message = "Transaction processed successfully"
	        clear_cart_and_order(false)
	      else
	        error_message = "Something went wrong and your transaction failed.<br/>"
	        error_message << "Please try again or contact us."
	        redirect_to_checkout(error_message)
        end
    else      
      # Redirect to checkout and allow them to enter info again.
      error_message = "Sorry, but your transaction didn't go through.<br/>"
      error_message << "#{order_success}<br/>"
      error_message << "Please try again or contact us."
      redirect_to_checkout(error_message)
    end
  end

  #############################################################################
  # PRIVATE METHODS 
  #############################################################################
  private
  
    # Finds cart
    def find_cart
      if !session[:cart]
        session[:cart] = Cart.new
      end
      @cart = session[:cart]
    end
    
    # Finds customer if they're logged in or not.
    def find_customer
      @customer = OrderUser.find_by_id(session[:customer])
    end
    
    # Finds an order
    def find_order
      Order.find(session[:order_id])
    rescue
      return nil
    end
    
    # Sets order, but sends the cusotmer back to the
    # start if there's not one found.
    #
    # Used on all methods in the checkout process
    # except the first one.
    #
    def find_order_and_redirect_if_nil
      @order = find_order
      # If there's no order redirect to index
      if @order == nil
        redir_string = "Looks like you haven't placed an order yet.\n\n"
        redir_string << "Please do so before trying to access that page."
        redirect_to_index(redir_string) and return false
      end
    end
    
    # Stubbed to be overridden in your custom controller if tax
    # is necessary.
    #
    # Gets called after order is successfully saved after checkout, before 
    # going to shipping.
    #
    def add_tax
      
    end

    # Clears the cart and possibly destroys the order
    # Called when the user wants to start over, or when the order is completed.
    def clear_cart_and_order(destroy_order = true)
      @cart.empty!
      if session[:order_id] then
        @order = Order.find(session[:order_id])
        if destroy_order then
          @order.destroy
        end
        session[:order_id] = nil
      end
    end

    # Redirects to index with a message
    def redirect_to_index(msg = nil)
      flash[:notice] = msg
      redirect_to :action => 'index'
    end
    # Redirects to checkout with a message
    def redirect_to_checkout(msg = nil)
      flash[:notice] = msg
      redirect_to :action => 'checkout'
    end
    
    # Redirects to proper shipping page.
    def redirect_to_shipping()
      redirect_to :action => @@action_after_checkout
    end
    
    # Execution action of checkout
    #
    # Tries to create an order. If it cant, returns to the page and shows errors.
    def do_checkout
      # We might be re-doing an existing order.
      # Don't want to create a new order for failed transactions, sooo
      if @order == nil then
        logger.info("\n\n\nCREATING NEW ORDER FROM POST\n\n\n")
        logger.info(params[:use_separate_shipping_address])
        logger.info("\n\n\n")
        create_order_from_post
      else
        logger.info("\n\n\nUPDATING EXISTING ORDER FROM POST\n\n\n")
        update_order_from_post
      end
      
      # Add cart items to order. Check inventory level first...
      # Now controlled by a preference in the Admin UI
      if Preference.find_by_name('store_use_inventory_control').is_true?
        removed_items = @cart.check_inventory()
        logger.info "REMOVED ITEMS: #{removed_items.inspect}"
        # If any items were removed, flash and alert.
        if removed_items.size > 0
          flash_msg = "The following item(s) have gone out of stock before you could purchase them:"
          for item_name in removed_items do
            flash_msg << "\n* #{item_name}"
          end
          flash_msg << "\n\n...The item(s) have been removed from your cart."

          if @cart.empty?
            redirect_to_index(flash_msg) and return
          else
            flash.now[:notice] = flash_msg
            render and return
          end
        end
      end

      @order.order_line_items = @items
      @order.save
      add_tax()
      # Save the order id to the session so we can find it later
      session[:order_id] = @order.id
      # All went well?
      logger.info("\n\nTRYING TO REDIRECT...")
      redirect_to_shipping and return
      #
    rescue
      logger.error "\n\nSomething went bad when trying to checkout..."
      stack_trace = $@.join("\n")
      logger.error "#{$!}\n\n#{stack_trace}\n"
      @shipping_address = OrderAddress.new unless @use_separate_shipping_address
      flash.now[:notice] = 'There were some problems with the information you entered.<br/><br/>Please look at the fields below.'
      render and return
    end

  # When is a cart not a cart?
  # When it was cleared without an open browser session.
  # That's why we sanitize dirty carts.
  #
  def sanitize! 
    if session[:order_id]
       session[:order_id].to_s
       order = Order.find(session[:order_id])
       if order.order_status_code_id != 1 && order.order_status_code_id != 3
         clear_cart_and_order(false)
       end
    end
  end

end
