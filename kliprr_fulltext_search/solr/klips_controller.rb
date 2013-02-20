class KlipsController < ApplicationController
  def index
    @klips = Klip.fulltext_search(params, current_user, page+1, 64)
    @total_pages = @klips.total_pages

    respond_to :html, :js
  end
end
