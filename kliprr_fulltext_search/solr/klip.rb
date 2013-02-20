class Klip < ActiveRecord::Base
  belongs_to :panel, :counter_cache => true
  belongs_to :user
  belongs_to :category

  searchable do
    text :original_url
    text :description

    string :content_type
    string :via
    integer :panel_id
    time    :created_at
  end

  def self.fulltext_search(params, logged_in_user = nil, page=1, per_page=64)
    conditions = parse_fulltext_conditions(logged_in_user, params)

    search_word = params[:q]
    search_word = Klip.original_url_filter(params[:source])+"*" unless params[:source].blank?

    solr_search = Klip.search do
      fulltext search_word
      conditions.each do |key,value|
        with key, value
      end
      order_by :created_at, :desc
      paginate :page => page, :per_page => per_page
    end
    solr_search.results
  end
end
