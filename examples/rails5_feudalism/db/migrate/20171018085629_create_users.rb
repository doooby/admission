class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.references :person , null: false
      t.jsonb :privileges
      t.timestamps
    end
  end
end
