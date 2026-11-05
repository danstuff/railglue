RSpec.describe "Homepage in a browser", type: :system do
  it "follows the home link" do
    visit root_path
    click_link "Home"
    expect(page).to have_css("h1", text: "Alpha")
  end
end
