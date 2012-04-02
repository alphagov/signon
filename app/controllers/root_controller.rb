class RootController < ApplicationController
  before_filter :authenticate_user!

  def index
  end
end
