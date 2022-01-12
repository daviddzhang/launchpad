class CommentsController < ApplicationController
  def create
    post = Post.find_by(id: params[:postId])
    comment = post.comments.create!(commenter: params[:commenter], comment: params[:comment])
    render json: comment.id
  end

  def upvote
    comment = Comment.find_by(id: params[:commentId])
    comment.update!(upvotes: comment.upvotes + 1)
  end

  def downvote
    comment = Comment.find_by(id: params[:commentId])
    comment.update!(downvotes: comment.downvotes + 1)
  end
end