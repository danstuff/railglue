RSpec.describe "Homepage", type: :request do
  it "renders using the test database" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("beta_test")
    expect(response.body).to include("Redis: PONG db3")
  end
end
