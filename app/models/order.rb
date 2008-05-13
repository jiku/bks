require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/order"

class Order < ActiveRecord::Base
  has_one :payment_method
  
  def get_shipping_prices
    prices = []
    # If they're in the USA (country #1... But changed to Norway now, == 137)
    address = self.shipping_address
    
    # TODO - set this country_id as a preference in the admin UI
    #
    if address.country_id == 137 then
      shipping_types = OrderShippingType.get_domestic
    else 
      shipping_types = OrderShippingType.get_foreign
    end

    for type in shipping_types
      type.calculate_price(self.weight)
      prices << type
    end

    return prices

  end
end
