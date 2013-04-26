class TracksController < ApplicationController
  respond_to :json, :html

  before_filter :authenticate_user!

  def index
    @track = Track.new
  end


  # Upload Track
  #
  def create
    @track = current_user.tracks.new(params[:track])

    if @track.save
      redirect_to tracks_path, :notice => "Track uploaded."
    else
      render "index", :status => :unprocessable_entity
    end

  end

  # Link on mix track
  #
  def link
    if @mix_track = MixTrack.find_by_id(params[:id])
      send_file @mix_track.attachment.path, :type => 'audio/mp3', :disposition => 'attachment'
    else
      render :nothing => true
    end
  end

  # Download mix track
  #
  def download

    if @mix_track = MixTrack.mixing_tracks(current_user.tracks)
      current_user.tracks.destroy_all
      respond_with do |format|
        format.html{
          send_file @mix_track.attachment.path, :type => 'audio/mp3', :disposition => 'attachment'
        }
        format.json{ render :json =>  { :url => link_track_url(@mix_track.id) }.to_json}
      end

    else

      respond_with do |format|
        format.html{ redirect_to tracks_path, :alert => "Mixing errors." }
        format.json{ render :json => "Mixing errors.".to_json, :status => :unprocessable_entity }
      end

    end

  end
end
