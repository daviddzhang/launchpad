class CommentsController < ApplicationController
  def create
    post = Post.find_by(params[:post_id])
    post.comments.create!(commenter: params[:commenter], comment: params[:comment])
  end
end