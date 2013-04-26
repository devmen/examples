class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.integer :user_id
      t.has_attached_file :attachment
      t.float :duration
      t.timestamps
    end
  end
end
