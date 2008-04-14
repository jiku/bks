#!% Exactly the same as manufacturers for now

class Manufacturer < ActiveRecord::Base
  has_and_belongs_to_many :products,
    :join_table => 'products_manufacturers'
  validates_presence_of :name
	# validates_uniqueness_of :name
  acts_as_tree :order => '-rank DESC'

	# Most used finder function for manufacturers.
	# Selects by alpha sort.
	def self.find_alpha
		find(:all, :order => 'name ASC')
	end

	# Finds ordered parent manufacturers.
	#
	def self.find_ordered_parents
	  find(
      :all,
      :conditions => "parent_id IS NULL OR parent_id = 0",
      :order => "-rank DESC"
    )
  end

	# Finds a list of related manufacturers for the manufacturer id's passed in
	# 
	# Uses the manufacturer ids passed in
	# 	- Finds products with the manufacturers applied (inside the subselect)
	#   - Find and returns manufacturers also manufacturerged to the products, but not passed in
	def self.find_related_manufacturers(manufacturer_id_list)
		manufacturer_id_list_string = manufacturer_id_list.join(",")
	  sql  = "SELECT items.id "
		sql << "FROM items "
		sql << "JOIN products_manufacturers on items.id = products_manufacturers.product_id "
		sql << "WHERE products_manufacturers.manufacturer_id IN (#{manufacturer_id_list_string}) "
		sql << "GROUP BY items.id HAVING COUNT(*)=#{manufacturer_id_list.length};"
		items = Item.find_by_sql(sql)

    item_ids = items.collect { |i| i.id }
    item_id_str = item_ids.join(',')

    if item_ids.size > 0		
  		sql =  "SELECT DISTINCT t.* FROM products_manufacturers pt, manufacturers t WHERE pt.product_id IN(#{item_id_str})"
  		sql << "AND t.id = pt.manufacturer_id "
  		sql << "AND t.id NOT IN (#{manufacturer_id_list_string});"
  		return find_by_sql(sql)
  	else
  	  return []
  	end
	end

	# Returns the number of products manufacturered with this item
	def product_count
	  @cached_product_count ||= self.products.count
	end
end