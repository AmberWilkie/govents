class Event < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.datetime :date
      t.string :location
      t.string :category
      t.string :tags
      t.string :link

      t.timestamps
    end
  end
end
