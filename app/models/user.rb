class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :strengthened  # in signonotron2/lib/devise/models/strengthened.rb

  attr_accessible :uid, :name, :email, :password, :password_confirmation, :twitter, :github, :beard
  attr_readonly :uid
end
