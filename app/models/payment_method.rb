class PaymentMethod < ActiveRecord::Base
  belongs_to :order
  
  validates_presence_of :name
	validates_uniqueness_of :name
  acts_as_tree :order => '-rank DESC'

	# Most used finder function for manufacturers.
	# Selects by alpha sort.
	def self.find_alpha
		find(:all, :order => 'name ASC')
	end

  # This probably isn't needed either.
  #
	# Finds ordered parent payment methods.
	#
	def self.find_ordered_parents
	  find(
      :all,
      :conditions => "parent_id IS NULL OR parent_id = 0",
      :order => "-rank DESC"
    )
  end
end