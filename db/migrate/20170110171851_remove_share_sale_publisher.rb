class RemoveShareSalePublisher < ActiveRecord::Migration
  def change
    share_sale_publisher = Doorkeeper::Application.find_by(name: "Share Sale Publisher")
    share_sale_publisher.delete if share_sale_publisher
  end
end
