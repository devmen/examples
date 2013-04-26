class CreateMixTracks < ActiveRecord::Migration
  def change
    create_table :mix_tracks do |t|
      t.has_attached_file :attachment

      t.timestamps
    end
  end
end
