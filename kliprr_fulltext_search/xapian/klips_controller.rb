class KlipsController < ApplicationController
  def index
      results = Klip.fulltext_search(params, current_user)
      @klips = result.page(page+1).per_page(64)
      @total_pages = result.total_pages

      respond_to :html, :js
    end
  end
end
