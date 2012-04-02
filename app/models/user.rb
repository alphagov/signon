class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable

  attr_accessible :uid, :name, :email, :password, :password_confirmation, :twitter, :github, :beard
  attr_readonly :uid

end
