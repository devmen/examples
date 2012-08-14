class ImagesController < ApplicationController
  before_filter :find_image, only: [:evaluate]
  respond_to :html, :js

  def index
    @images = Image.all
  end

  def evaluate
    @rank = params[:rank].to_i
    @image.rate(@rank)
    @average_rank = Image.average_rank
    @rank_class = Image::RANKS[@rank] + "star"
    respond_with @image
  end

  private
  def find_image
    @image = Image.find(params[:id])
  end
end
