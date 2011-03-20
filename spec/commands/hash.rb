require 'spec_helper'

def store_simple_hash(redis)
  @stored_hash = {
    'field'  => 'bar',
    'field1' => 'bar1',
    'field2' => 'bar2'
  }

  @stored_hash.each { |k,v| redis.hset 'foo', k, v}
end

describe EM::Hiredis do
  include EM::Spec

  describe "#hdel" do
    context "when the hash field exists" do
      it "should delete the field and return true" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'bar'

          redis.hdel 'foo', 'field' do |deleted|
            deleted.should be true
            redis.hget 'foo', 'field' do |value|
              value.should be nil
              done
            end
          end
        end
      end
    end

    context "when the hash field doesn't exist" do
      it "should return false" do
        hiredis_test do |redis|

          redis.hdel 'foo', 'field' do |deleted|
            deleted.should be false
              done
          end
        end
      end
    end
  end

  describe "#hexists" do
    context "when the hash field exists" do
      it "should return true" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'bar'

          redis.hexists 'foo', 'field' do |exists|
            exists.should be true
            done
          end
        end
      end
    end

    context "when the hash field doesn't exist" do
      it "should return true" do
        hiredis_test do |redis|

          redis.hexists 'foo', 'field' do |exists|
            exists.should be false
            done
          end
        end
      end
    end
  end

  describe "#hget" do
    context "when the hash field exists" do
      it "should return the value" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'bar'

          redis.hget 'foo', 'field' do |value|
            value.should == 'bar'
            done
          end
        end
      end
    end

    context "when the hash field exists" do
      it "should return nil" do
        hiredis_test do |redis|

          redis.hget 'foo', 'field' do |value|
            value.should == nil
            done
          end
        end
      end
    end
  end

  describe "#hgetall" do
    it "should return the fields and values in a hash" do
      hiredis_test do |redis|

        store_simple_hash redis

        redis.hgetall 'foo' do |values|
          values.should == @stored_hash.flatten
          done
        end
      end
    end
  end

  describe "#hincrby" do
    it "should increment a hash field value by N" do
      hiredis_test do |redis|

        redis.hset 'foo', 'field', 10
        redis.hincrby 'foo', 'field', 3 do |new_value|
          new_value.should be 13
          redis.hget'foo', 'field' do |value|
            value.should == "13"
            done
          end
        end

      end
    end
  end

  describe "#hkeys" do
    it "should return the fields of a hash" do
      hiredis_test do |redis|

        store_simple_hash redis

        redis.hkeys 'foo' do |keys|
          keys.should == @stored_hash.keys
          done
        end
      end
    end
  end

  describe "#hlen" do
    it "should return the number of fields of a hash" do
      hiredis_test do |redis|

        store_simple_hash redis

        redis.hlen 'foo' do |num_keys|
          num_keys.should == @stored_hash.keys.length
          done
        end
      end
    end
  end

  describe "#hmget" do
    it "should return the values for the hash fields specified" do
      hiredis_test do |redis|

        store_simple_hash redis

        redis.hmget 'foo', @stored_hash.keys do |values|
          values.should == @stored_hash.values
          done
        end
      end
    end
  end

  describe "#hmset" do
    it "should store multiple hash field values" do
      hiredis_test do |redis|

        hash = {
          'field'  => 'bar',
          'field1' => 'bar1',
          'field2' => 'bar2'
        }

        redis.hmset 'foo', hash.flatten
        redis.hgetall 'foo' do |values|
          values.should == hash.flatten
          done
        end
      end
    end
  end

  describe "#hset" do
    context "when the hash field exists" do
      it "should set the field and return false" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'bar'
          redis.hset 'foo', 'field', 'baz' do |set|
            set.should be false
            redis.hget 'foo', 'field' do |value|
              value.should == 'baz'
              done
            end
          end
        end
      end
    end

    context "when the hash field doesn't exist" do
      it "should set the field and return true" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'baz' do |set|
            set.should be true
            redis.hget 'foo', 'field' do |value|
              value.should == 'baz'
              done
            end
          end
        end
      end
    end
  end

  describe "#hsetnx" do
    context "when the hash field exists" do
      it "should not set the field and return false" do
        hiredis_test do |redis|

          redis.hset 'foo', 'field', 'bar'
          redis.hsetnx 'foo', 'field', 'baz' do |set|
            set.should be false
            redis.hget 'foo', 'field' do |value|
              value.should == 'bar'
              done
            end
          end
        end
      end
    end

    context "when the hash field doesn't exist" do
      it "should set the field and return true" do
        hiredis_test do |redis|

          redis.hsetnx 'foo', 'field', 'baz' do |set|
            set.should be true
            redis.hget 'foo', 'field' do |value|
              value.should == 'baz'
              done
            end
          end
        end
      end
    end
  end

  describe "#hvals" do
    it "should return all of the hash's values" do
      hiredis_test do |redis|

        store_simple_hash redis

        redis.hvals 'foo' do |values|
          values.should == @stored_hash.values
          done
        end
      end
    end
  end
end
