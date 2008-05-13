class CreatePaymentMethods < ActiveRecord::Migration
  def self.up
    
    # Makes the table to hold manufacturers
    create_table :payment_methods do |t|
	    t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "rank", :integer
      t.column "parent_id", :integer, :default => 0, :null => false
      t.timestamps
    end

    # Adds the foreign key
    add_column :orders, :payment_method_id, :integer
          
  	add_index :payment_methods, ['name'], :name => 'name'    
  end

  def self.down
    drop_table :payment_methods
    remove_column :orders, :payment_method_id
  end
end