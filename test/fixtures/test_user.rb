class TestUser < ActiveRecord::Base
  acts_as_tritonn
  has_many :test_comments, :dependent => :destroy

end