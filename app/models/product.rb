require_dependency RAILS_ROOT + "/vendor/plugins/substruct/app/models/product"

class Product < Item
	has_and_belongs_to_many :manufacturers

	# Finds products by list of manufacturer ids passed in
	#
	# We could JOIN multiple times, but selecting IN grabs us the products
	# and using GROUP BY & COUNT with the number of manufacturer id's given
	# is a faster approach according to freenode #mysql
	def self.find_by_manufacturers(manufacturer_ids, find_available=false, order_by="items.date_available DESC")
		sql =  "SELECT * "
		sql << "FROM items "
		sql << "JOIN products_manufacturers on items.id = products_manufacturers.product_id "
		sql << "WHERE products_manufacturers.tag_id IN (#{manufacturer_ids.join(",")}) "
		sql << "AND #{CONDITIONS_AVAILABLE}" if find_available==true
		sql << "GROUP BY items.id HAVING COUNT(*)=#{manufacturer_ids.length} "
		sql << "ORDER BY #{order_by};"
		find_by_sql(sql)
	end
	
	#############################################################################
	# INSTANCE METHODS
	#############################################################################

  substruct_deprecate :manufacturers= => :manufacturer_ids=

  # This method is DEPRECATED.
  # This method has an equivalent auto-generated but must be here to not
  # generate an infinite looping. It can be simply excluded after some time.
  def manufacturer_ids=(list)
    manufacturers.clear
    for id in list
      manufacturers << Manufacturer.find(id) if !id.empty?
    end
  end
end