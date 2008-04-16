#!% Do a rollback if this doesn't work!
#!% I THINK I have included everything that is used for tags, but you never know.
#!% Also, I'd like to simplify this, but have to think through whether or not having multiple manufacturers is a good idea or not.

class CreateManufacturers < ActiveRecord::Migration
  def self.up
    
    # Makes the table to hold manufacturers
    create_table :manufacturers do |t|
	    t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "rank", :integer
      t.column "parent_id", :integer, :default => 0, :null => false
      t.timestamps
    end

    # Adds the foreign key
    add_column :products, :manufacturer_id, :integer
      
    create_table :manufacturer_images do |t|
      t.column "image_id", :integer, :default => 0, :null => false
      t.column "manufacturer_id", :integer, :default => 0, :null => false
      # t.column "id", :primary_key
      t.column "rank", :integer
    end
    
  	add_index :manufacturers, ['name'], :name => 'name'
    add_index :manufacturer_images, ['manufacturer_id', 'image_id'], :name => 'main'
    
		puts 'Adding default rights for Manufacturers...'
		Load in new roles - otherwise nobody would have access!
		rights = Right.create(
		  [ 
			  { :name => 'Manufacturers - Admin', :controller => 'manufacturers', :actions => '*' },
			  { :name => 'Manufacturers - CRUD', :controller => 'manufacturers', :actions => 'new,create,edit,update,destroy' },
			  { :name => 'Manufacturers - View', :controller => 'manufacturers', :actions => 'index,list,search,edit,show' }
      ]
		)
  end

  def self.down
    drop_table :manufacturers
    remove_column :products, :manufacturer_id
    drop_table :manufacturer_images
  end
end