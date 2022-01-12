class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def show
    client_side_endpoints(
      :create_comment_path
    )

    @post = Post.find(params[:id])
    @comments_props = {
      postId: @post.id,
      comments: @post.comments.all.map do |comment|
        {
          commenter: comment.commenter,
          comment: comment.comment
        }
      end
    }
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.create!(post_params)
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    @post.update!(post_params)
  end

  private

    def post_params
      params.require(:post).permit(:title, :text)
    end
end
