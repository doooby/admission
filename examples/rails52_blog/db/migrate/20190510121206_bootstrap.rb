class Bootstrap < ActiveRecord::Migration[5.2]
  def change

    create_table :users do |t|
      t.string :name, null: false
      t.string :privilege
    end

    create_table :articles do |t|
      t.references :author
      t.string :title
      t.text :body
    end

    create_table :messages do |t|
      t.references :article
      t.references :user
      t.text :body
    end

  end
end
