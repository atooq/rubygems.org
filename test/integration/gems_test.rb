require "test_helper"

class GemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
  end

  test "gem page with a non valid HTTP_ACCEPT header" do
    get rubygem_path(@rubygem), headers: { "HTTP_ACCEPT" => "application/mercurial-0.1" }
    assert page.has_content? "1.0.0"
  end

  test "gems page with atom format" do
    get rubygems_path(format: :atom)
    assert_response :success
    assert_equal "application/atom+xml", response.content_type
    assert page.has_content? "sandworm"
  end

  test "versions with atom format" do
    create(:version, rubygem: @rubygem)
    get rubygem_versions_path(@rubygem, format: :atom)
    assert_equal "application/atom+xml", response.content_type
    assert page.has_content? "sandworm"
  end

  test "canonical url for gem points to most recent version" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_path(@rubygem)
    css = %(link[rel="canonical"][href="http://localhost/gems/sandworm/versions/1.1.1"])
    assert page.has_css?(css, visible: false)
  end

  test "canonical url for an old version" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_version_path(@rubygem, "1.0.0")
    css = %(link[rel="canonical"][href="http://localhost/gems/sandworm/versions/1.0.0"])
    assert page.has_css?(css, visible: false)
  end
end

class GemsSystemTest < SystemTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:version, rubygem: @rubygem, number: "1.1.1")
  end

  test "version navigation" do
    visit rubygem_version_path(@rubygem, "1.0.0")
    click_link "Next version →"
    assert_equal page.current_path, rubygem_version_path(@rubygem, "1.1.1")
    click_link "← Previous version"
    assert_equal page.current_path, rubygem_version_path(@rubygem, "1.0.0")
  end

  test "subscribe to a gem" do
    visit rubygem_path(@rubygem, as: @user.id)
    assert page.has_css?("a#subscribe")

    click_link "Subscribe"

    assert page.has_content? "Unsubscribe"
    assert_equal @user.subscribed_gems.first, @rubygem
  end

  test "unsubscribe to a gem" do
    create(:subscription, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem, as: @user.id)
    assert page.has_css?("a#unsubscribe")

    click_link "Unsubscribe"

    assert page.has_content? "Subscribe"
    assert_empty @user.subscribed_gems
  end
end
