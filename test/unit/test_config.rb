require 'test_helper'

describe Treeline::Config do
  describe "Without any preset YAML configs" do
    before do
      @config = Treeline::Config.new
    end

    it "builds a proper config hash for Redis" do
      @logger = Logger.new STDERR

      @config.host = "localhost"
      @config.port = 12345
      @config.timeout = 10
      @config.password = "foo"
      @config.database = 3
      @config.logger = @logger

      config = @config.redis_config

      assert_equal "localhost", config[:host]
      assert_equal 12345, config[:port]
      assert_equal 10, config[:timeout]
      assert_equal "foo", config[:password]
      assert_equal 3, config[:db]
      assert_equal @logger, config[:logger]

    end

    it "reads configuration from a YAML config file" do
      base_dir = File.dirname(File.path(__FILE__))
      yaml_file = File.join(base_dir, "..", "test_config.yaml")
      @config.load_from_yaml(yaml_file)
      assert_equal "localhost", @config.host
      assert_equal 12345, @config.port
      assert_equal 10, @config.timeout
      assert_equal "foo", @config.password
      assert_equal 3, @config.database
      assert_equal "treecurve", @config.namespace
    end
  end

  describe "when in a Rails app without a config file" do
    before do
      RAILS_ROOT = File.join(File.dirname(File.path(__FILE__)), "..", "gibberish")
      @config = Treeline::Config.new
    end

    after do
      Object.send(:remove_const, :RAILS_ROOT)
    end

    it "should load successfully without any configs." do
      ["database","host","port","timeout","password","logger","namespace"].each do |setting|
        assert_equal nil, @config.instance_variable_get("@#{setting}")
      end
    end
  end

  describe "when in a Rails app with a config file" do
    before do
      RAILS_ROOT = File.join(File.dirname(File.path(__FILE__)), "..", "fake_rails")
      @config = Treeline::Config.new
    end

    after do
      Object.send(:remove_const, :RAILS_ROOT)
    end

    it "should load the config/treeline.yaml file" do
      assert_equal "localhost", @config.host
      assert_equal 12345, @config.port
      assert_equal 10, @config.timeout
      assert_equal "foo", @config.password
      assert_equal 3, @config.database
      assert_equal "treecurve", @config.namespace
    end
  end

  describe "when TREELINE_YAML is defined" do
    before do
      TREELINE_YAML = File.join(File.dirname(File.path(__FILE__)), "..", "test_config.yaml")
      @config = Treeline::Config.new
    end

    after do
      Object.send(:remove_const, :TREELINE_YAML)
    end

    it "should load the specified yaml file" do
      assert_equal "localhost", @config.host
      assert_equal 12345, @config.port
      assert_equal 10, @config.timeout
      assert_equal "foo", @config.password
      assert_equal 3, @config.database
      assert_equal "treecurve", @config.namespace
    end
  end

  describe "when TREELINE_YAML is defined, but doesn't exist" do
    before do
      TREELINE_YAML = File.join(File.dirname(File.path(__FILE__)), "..", "fake_config.yaml")
    end

    after do
      Object.send(:remove_const, :TREELINE_YAML)
    end

    it "should raise an exception" do
      assert_raises RuntimeError do 
        @config = Treeline::Config.new
      end
    end
  end
end