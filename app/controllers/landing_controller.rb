class LandingController < ApplicationController
  def index
    @time = DateTime.now
    @posts = Post.all
  end
end
