require 'spec_helper'


describe EM::Hiredis do
  include EM::Spec

  #
  # before/after don't seem to work properly with EM::Spec?
  #
  #before do
  # @redis = EM::Hiredis::Client.connect(:host => TEST_HOST[:host]
  #end

  #after do
  # @redis.disconnect
  #end

  describe "#del" do
    it "should delete the keys and return the number of keys deleted" do
      hiredis_test do |redis|

        redis.mset 'foo',  'bar',
                   'foo1', 'bar1',
                   'foo2', 'bar2',
                   'foo3', 'bar3'

        wait_for_tests 4
        redis.del 'foo1', 'foo2' do |num_deletions|
          num_deletions.should be 2

          ['foo', 'foo3'].each do |not_deleted_key|
            redis.exists(not_deleted_key) { |exists| exists.should be true; finished_test }
          end

          ['foo1', 'foo2'].each do |deleted_key|
            redis.exists(deleted_key) { |exists| exists.should be false; finished_test }
          end
        end

      end
    end
  end

  describe "#exists" do
    context "when the key exists" do
      it "should return true" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar' do
            redis.exists 'foo' do |value|
              value.should be true
              done
            end
          end

        end
      end
    end

    context "when the key doesn't exist" do
      it "should return false" do
        hiredis_test do |redis|

          redis.exists 'foo' do |value|
            value.should be false
            done
          end

        end
      end
    end
  end

  describe "#expire / #ttl" do
    context "if the key exists" do
      it "should set the ttl and return true" do
        hiredis_test do |redis|

          wait_for_tests 2

          redis.set 'foo', 'bar'
          redis.ttl('foo') { |ttl| ttl.should be -1; finished_test}
          redis.expire 'foo', 10 do |set_ttl|
            set_ttl.should be true
            # shouldn't take a second to complete the command
            redis.ttl('foo') { |ttl| ttl.should be 10; finished_test}
          end

        end
      end
    end

    context "if the key doesn't exist" do
      it "should return false" do
        hiredis_test do |redis|

          redis.expire 'foo', 10 do |set_ttl|
            set_ttl.should be false
            done
          end

          redis.ttl 'foo' do |ttl|
            ttl.should be -1
          end

        end
      end
    end
  end

  describe "#expireat" do
    context "if the key exists" do
      it "should set the ttl and return true" do
        hiredis_test do |redis|

          wait_for_tests 2

          redis.set 'foo', 'bar'
          redis.ttl('foo') { |ttl| ttl.should be -1; finished_test}

          redis.expireat 'foo', Time.now.to_i + 10 do |set_ttl|
            set_ttl.should be true
            # shouldn't take a second to complete the command
            redis.ttl('foo') do |ttl|
              ttl.should <= 10
              ttl.should > 0
              finished_test
            end
          end

        end
      end
    end

    context "if the key doesn't exist" do
      it "should return false" do
        hiredis_test do |redis|

          redis.expireat 'foo', Time.now.to_i + 10 do |set_ttl|
            set_ttl.should be false
            done
          end

        end
      end
    end
  end

  describe "#keys" do
    it "should return matching keys" do
      hiredis_test do |redis|

        redis.mset 'foo',  'bar',
                   'foo1', 'bar1',
                   'foo2', 'bar2',
                   'foo3', 'bar3'

        redis.keys 'foo[23]' do |keys|
          keys.should =~ ['foo2', 'foo3']
          done
        end

      end
    end
  end

  describe "#move" do
    context "if the key was moved" do
      it "should return true" do
        hiredis_test do |redis|

          redis.select 0
          redis.set 'foo', 'bar'

          redis.move 'foo', 1 do |moved|
            moved.should be true
            redis.exists('foo') do |exists|
              exists.should be false
              redis.select 1
              redis.exists('foo') do |exists|
                exists.should be true
                done
              end
            end
          end

        end
      end
    end

    context "if the key wasn't moved" do
      it "should return false" do
        hiredis_test do |redis|

          redis.select 1
          redis.set 'foo', 'bar'
          redis.select 0
          redis.set 'foo', 'bar'

          redis.move 'foo', 1 do |moved|
            moved.should be false
            redis.exists('foo') do |exists|
              exists.should be true
              redis.select 1
              redis.exists('foo') do |exists|
                exists.should be true
                done
              end
            end
          end

        end
      end
    end
  end

  describe "#persist" do
    context "if the key has a timeout" do
      it "should remove the ttl and return true" do
        hiredis_test do |redis|

          wait_for_tests 2

          redis.set 'foo', 'bar'
          redis.ttl('foo') { |ttl| ttl.should be -1; finished_test}

          redis.expireat 'foo', Time.now.to_i + 10
          redis.ttl('foo') { |ttl| ttl.should > 0; finished_test}
          redis.persist 'foo' do |timeout_removed|
            timeout_removed.should be true
            redis.ttl('foo') { |ttl| ttl.should be -1; finished_test}
          end

        end
      end
    end

    context "if the key doesn't exist" do
      it "should return false" do
        hiredis_test do |redis|

          redis.persist 'foo' do |timeout_removed|
            timeout_removed.should be false
            done
          end

        end
      end
    end

    context "if the key didn't have a timeout" do
      it "should return false" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar'
          redis.persist 'foo' do |timeout_removed|
            timeout_removed.should be false
            done
          end

        end
      end
    end
  end

  describe "#randomkey" do
    context "when the db is empty" do
      it "should return nil" do
        hiredis_test do |redis|

          redis.randomkey do |key|
            key.should be nil
            done
          end

        end
      end
    end

    it "should return a random key" do
      hiredis_test do |redis|

        redis.mset 'foo',  'bar',
                   'foo1', 'bar1',
                   'foo2', 'bar2',
                   'foo3', 'bar3'

        redis.randomkey do |key|
          ['foo', 'foo1', 'foo2', 'foo3'].should include key
          done
        end

      end
    end
  end

  describe "#rename" do
    it "should rename the key" do
      hiredis_test do |redis|

        redis.set 'foo', 'bar'
        redis.rename 'foo', 'foo_new'

        wait_for_tests 2
        redis.exists('foo') { |exists| exists.should be false; finished_test }
        redis.exists('foo_new') { |exists| exists.should be true; finished_test }

      end
    end
  end

  describe "#renamenx" do
    context "if the new key doesn't exist" do
      it "should rename the key and return true" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar'

          wait_for_tests 3
          redis.renamenx 'foo', 'foo_new' do |renamed|
            renamed.should be true
            finished_test
          end

          redis.exists('foo') { |exists| exists.should be false; finished_test }
          redis.exists('foo_new') { |exists| exists.should be true; finished_test }

        end
      end
    end

    context "if the new key already exists" do
      it "should not rename the key and return false" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar'
          redis.set 'foo_new', 'bar_new'

          wait_for_tests 3

          redis.renamenx 'foo', 'foo_new' do |renamed|
            renamed.should be false
            finished_test
          end

          redis.exists('foo') { |exists| exists.should be true; finished_test }
          redis.get('foo_new') { |value| value.should == 'bar_new'; finished_test }

        end
      end
    end
  end

  describe "#set / #get" do
    context "when the key exists" do
      it "should set/get it" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar' do
            redis.get 'foo' do |value|
              value.should == 'bar'
              done
            end
          end

        end
      end
    end

    describe "#get" do
      context "when the key doesn't exist" do
        it "should return nil" do
          hiredis_test do |redis|

            redis.get "foo" do |value|
              value.should == nil
              done
            end

          end
        end
      end
    end
  end

  describe "#sort" do
    it "should do a basic sort and return the results" do
      hiredis_test do |redis|

        test_keys = {
          'foo'  => 'bar',
          'foo1' => 'bar1',
          'foo2' => 'bar2',
          'foo3' => 'bar3'
        }

        redis.mset test_keys
        test_keys.keys.each do |key|
          redis.rpush 'list', key
        end

        redis.sort 'list', :get => ['*', '#'], :order => :asc, :alpha => true do |sorted_values|
          sorted_values.should == ["bar", "foo", "bar1", "foo1", "bar2", "foo2", "bar3", "foo3"]
          done
        end

      end
    end
  end

  describe "#type" do
    context "when the key exists" do
      it "should return the key type" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar'
          redis.lpush 'list', 'foo'

          wait_for_tests 2

          redis.type 'foo' do |type|
            type.should == 'string'
            finished_test
          end

          redis.type 'list' do |type|
            type.should == 'list'
            finished_test
          end
        end
      end
    end

    context "when the key doesn't exist" do
      it "should return 'none'" do
        hiredis_test do |redis|

          redis.type 'foo' do |type|
            type.should == 'none'
            done
          end

        end
      end
    end
  end
end
