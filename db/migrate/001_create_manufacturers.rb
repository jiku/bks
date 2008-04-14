#!% Do a rollback if this doesn't work!
#!% I THINK I have included everything that is used for tags, but you never know.
#!% Also, I'd like to simplify this, but have to think through whether or not having multiple manufacturers is a good idea or not.

class CreateManufacturers < ActiveRecord::Migration
  def self.up
    create_table :manufacturers do |t|
	    t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "rank", :integer
      t.column "parent_id", :integer, :default => 0, :null => false
      t.timestamps
    end
    
    #!% This is a simpler way of doing the same thing as below, but a simpler relation, with manufacturer:has_many items + item:belongs_to manufacturer
    # add_column :items, :manufacturer_id, :integer
    
		# Adds a table for storing manufactured products #!% BUT THIS IS REDUNDANT because every product HAS to have a manufacturer... Look into simplifying this.
		create_table "products_manufacturers", :id => false do |t|
	    t.column "product_id", :integer, :default => 0, :null => false
			t.column "manufacturer_id", :integer, :default => 0, :null => false
		end

	#	create_table :manufacturers_products, :id => false do |t|
	 
	 #   t.column "product_id", :integer, :default => 0, :null => false
	#		t.column "manufacturer_id", :integer, :default => 0, :null => false
	#	end
    
    create_table :manufacturer_images do |t|
      t.column "image_id", :integer, :default => 0, :null => false
      t.column "manufacturer_id", :integer, :default => 0, :null => false
      # t.column "id", :primary_key
      t.column "rank", :integer
    end
    
  	add_index :manufacturers, ['name'], :name => 'name'
    add_index :products_manufacturers, ['product_id', 'manufacturer_id'], :name => 'product_manufacturers'
    add_index :manufacturer_images, ['manufacturer_id', 'image_id'], :name => 'main'
    
		# puts 'Adding default rights for Manufacturers...'
		# Load in new roles - otherwise nobody would have access!
		# rights = Right.create(
		#	[ 
		#		{ :name => 'Manufacturers - Admin', :controller => 'manufacturers', :actions => '*' },
		#		{ :name => 'Manufacturers - CRUD', :controller => 'manufacturers', :actions => 'new,create,edit,update,destroy' },
		#		{ :name => 'Manufacturers - View', :controller => 'manufacturers', :actions => 'index,list,search,edit,show' }
		#	]
		# )
  end

  def self.down
    drop_table :manufacturers
    # remove_column :items, :manufacturer_id
    drop_table :products_manufacturers
    # drop_table :manufacturers_products
    drop_table :manufacturer_images
    #!% I don't need to remove these indexes because the tables were dropped.
    # remove_index :manufacturers, :name => 'name'
    # remove_index :products_manufacturers, :name => 'product_manufacturers'
    # remove_index :manufacturer_images, :name  => 'main'
  end
end