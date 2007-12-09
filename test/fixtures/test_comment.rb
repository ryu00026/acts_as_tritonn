class TestComment < ActiveRecord::Base
  acts_as_tritonn
  belongs_to :test_user

end