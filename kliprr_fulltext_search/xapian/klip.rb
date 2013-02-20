class Klip < ActiveRecord::Base
  belongs_to :panel, :counter_cache => true
  belongs_to :user
  belongs_to :category

  xapit do
    text :original_url
    text :description
    sortable :created_at
    field :content_type
    field :via
    field :panel_id
  end

  def self.fulltext_search(params, logged_in_user = nil)
    conditions = {}

    if params[:q]
      case params[:search_type]
      when "videos"
        conditions[:content_type] = "video"
      when "klips"
        conditions[:content_type] = "image"
      else
        conditions[:content_type] = ["video", "image"]
      end
    else
      conditions[:content_type] = ["video", "image"]
    end

    if logged_in_user && params[:q]
      follow_type = params[:follow_type].present? ? params[:follow_type] : "follow"
      panel_ids = logged_in_user.followed_panels_ids
      conditions[:panel_id] = panel_ids if panel_ids.any?
    end

    conditions[:via] = "upload" if params[:uploads]

    search_word = params[:q]
    search_word = Klip.original_url_filter(params[:source])+"*" unless params[:source].blank?

    Klip.search(search_word).where(conditions).order(:created_at, :desc)
  end
end
