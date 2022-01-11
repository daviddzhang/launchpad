require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    it "successfully creates a Post" do
      post :create, params: { post: { title: "A title", text: "Some text" } }
      new_post = Post.last
      expect(new_post.title).to eq("A title")
      expect(new_post.text).to eq("Some text")
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET #edit" do
    it "returns http success" do
      post = create(:post)
      get :edit, params: { id: post.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #update" do
    it "successfully updates a post" do
      new_post = create(:post)
      post :update, params: { id: new_post.id, post: { title: "A title", text: "Some text" } }
      new_post.reload
      expect(new_post.title).to eq("A title")
      expect(new_post.text).to eq("Some text")
      expect(response).to have_http_status(:no_content)
    end
  end
end
