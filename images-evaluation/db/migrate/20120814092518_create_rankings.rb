class CreateRankings < ActiveRecord::Migration
  def change
    create_table :rankings do |t|
      t.integer :image_id
      t.integer :rating

      t.timestamps
    end
    add_index :rankings, :image_id
  end
end
