require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/order_line_item"

class OrderLineItem < ActiveRecord::Base
  # This returns the name of the order line item, so here we should add the manufacturer.
  
  def name
    if !self.item.nil?
      return Manufacturer.find(self.item.manufacturer_id).name + ' ' + self.item.name
    else
      return self.attributes['name']
    end
  end
end