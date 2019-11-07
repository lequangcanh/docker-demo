class AddCheckedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :checked, :boolean, default: false
  end
end
