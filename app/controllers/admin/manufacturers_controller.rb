class Admin::ManufacturersController < Admin::BaseController
  def index
    list
    render :action => 'list'
  end

	# List manages addition/deletion of items through ajax
  def list
    @title = 'Manage Manufacturers'
    @manufacturers = Manufacturer.find_ordered_parents()
    
    if params[:id]
      @parent_manufacturer = Manufacturer.find_by_name(params[:id])
      # If given faulty parent manufacturer, redirect back to list with no ID
      # ...and show an error.
      if !@parent_manufacturer
        flash.now[:notice] = "Sorry, we couldn't find the manufacturer you were looking for"
        render and return
      end
      @parent_manufacturer_id = @parent_manufacturer.id
      @manufacturers = @parent_manufacturer.children
    end
  end
  
  # AJAX
  #
  def update_manufacturer_rank
    params[:manufacturer_list].each_index do |i|
      manufacturer = Manufacturer.find(params[:manufacturer_list][i])
      if manufacturer
        manufacturer.rank = i
        manufacturer.save
      end
    end
    render :nothing => true
  end

	# Creation returns text to the page which is inserted as a partial.
	#
  def create
    @manufacturer = Manufacturer.new(params[:manufacturer])
    if params[:id]
      @manufacturer.parent_id = params[:id]
    end
    if @manufacturer.save
      render(:partial => 'manufacturer_list_row', :locals => {:manufacturer_list_row => @manufacturer})
    else
      render :text => ""
    end
  end

	# Called via AJAX
  def update
    @manufacturer = Manufacturer.find(params[:id])
		@manufacturer.name = params[:name]
    if !@manufacturer.save
      render(:update) do |page| 
        page.alert "Something went wrong saving your manufacturer.\n\nRemember, manufacturer names have to be unique."
      end
    else
      render(:update) do |page| 
        page.replace "manufacturer_#{@manufacturer.id}", :partial => 'manufacturer_list_row', :locals => { :manufacturer_list_row => @manufacturer }
        page.sortable(
    			'manufacturer_list',
    			:url => { :action => 'update_manufacturer_rank' }
    		)
      end
    end
  end

	# Called via AJAX. 
  def destroy
    @manufacturer = Manufacturer.find(params[:id])
		manufacturer_id = @manufacturer.id
		@manufacturer.destroy
		# Render nothing to denote success
    render :text => ""
  end
end