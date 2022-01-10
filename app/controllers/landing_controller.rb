class LandingController < ApplicationController
  def index
    @time = DateTime.now
  end
end
