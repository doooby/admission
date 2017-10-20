class CreatePossessions < ActiveRecord::Migration[5.1]
  def change
    create_table :possessions do |t|
      t.string :name, null: false
      t.belongs_to :person, null: false
      t.timestamps
    end
  end
end
