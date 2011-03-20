require 'spec_helper'


describe EM::Hiredis do
  include EM::Spec

  describe "#append" do
    it "should append a string to a key and return the new length" do
      hiredis_test do |redis|

        redis.set 'foo', 'bar'

        redis.append 'foo', 'baz' do |length|
          length.should be 6
          redis.get 'foo' do |new_value|
            new_value.should == 'barbaz'
            done
          end
        end

      end
    end
  end

  describe "#decr" do
    it "should decrement an integer key by one and return the new value" do
      hiredis_test do |redis|

        redis.set 'foo', 10

        redis.decr 'foo' do |returned_value|
          returned_value.should be 9
          redis.get 'foo' do |new_value|
            new_value.should == '9'
            done
          end
        end

      end
    end
  end

  describe "#decrby" do
    it "should decrement an integer key by N and return the new value" do
      hiredis_test do |redis|

        redis.set 'foo', 10

        redis.decrby 'foo', 3 do |returned_value|
          returned_value.should be 7
          redis.get 'foo' do |new_value|
            new_value.should == '7'
            done
          end
        end

      end
    end
  end

  describe "#getbit / #setbit" do
    it "should set / get the bit value of a key at a certain position" do
      hiredis_test do |redis|

        redis.setbit 'foo', 2, 1

        wait_for_tests 4
        redis.getbit('foo', 0) { |bit| bit.should be 0; finished_test }
        redis.getbit('foo', 1) { |bit| bit.should be 0; finished_test }
        redis.getbit('foo', 2) { |bit| bit.should be 1; finished_test }
        redis.getbit('foo', 3) { |bit| bit.should be 0; finished_test }

      end
    end
  end

  describe "#getrange" do
    it "should return a substring of a string" do
      hiredis_test do |redis|

        redis.set 'foo', 'http://ryoukai.net/cv'

        redis.getrange 'foo', 7, -1 do |substring|
          substring.should == 'ryoukai.net/cv'
          done
        end

      end
    end
  end

  describe "#getset" do
    it "should set a key and return the previous value" do
      hiredis_test do |redis|

        redis.set 'foo', 'bar'
        redis.getset 'foo', 'baz' do |old_value|
          old_value.should == 'bar'
          redis.get 'foo' do |new_value|
            new_value.should == 'baz'
            done
          end
        end

      end
    end
  end

  describe "#incr" do
    it "should increment an integer key by one and return the new value" do
      hiredis_test do |redis|

        redis.set 'foo', 10

        redis.incr 'foo' do |returned_value|
          returned_value.should be 11
          redis.get 'foo' do |new_value|
            new_value.should == '11'
            done
          end
        end

      end
    end
  end

  describe "#incrby" do
    it "should increment an integer key by N and return the new value" do
      hiredis_test do |redis|

        redis.set 'foo', 10

        redis.incrby 'foo', 3 do |returned_value|
          returned_value.should be 13
          redis.get 'foo' do |new_value|
            new_value.should == '13'
            done
          end
        end

      end
    end
  end

  describe "#mget / #mset" do
    it "should set / get many keys" do
      hiredis_test do |redis|

        keys = {
          'foo'  => 'bar',
          'foo1' => 'bar1',
          'foo2' => 'bar2',
          'foo3' => 'bar3'
        }

        redis.mset keys.flatten
        redis.mget keys.keys do |values|
          values.should == keys.values
          done
        end
      end
    end
  end

  describe "#msetnx" do
    context "if a key is already set" do
      it "should not set any of the keys" do
        hiredis_test do |redis|

          keys = {
            'foo'  => 'bar',
            'foo1' => 'bar1',
            'foo2' => 'bar2',
            'foo3' => 'bar3'
          }

          redis.set 'foo', 'baz'
          redis.msetnx keys.flatten
          redis.mget keys.keys do |values|
            values.should == ['baz', nil, nil, nil]
            done
          end
        end
      end
    end

    context "if none of the keys are already set" do
      it "should set all the given keys" do
        hiredis_test do |redis|

          keys = {
            'foo'  => 'bar',
            'foo1' => 'bar1',
            'foo2' => 'bar2',
            'foo3' => 'bar3'
          }

          redis.msetnx keys.flatten
          redis.mget keys.keys do |values|
            values.should == keys.values
            done
          end
        end
      end
    end
  end

  describe "#setex" do
    it "should set both a key and its ttl" do
      hiredis_test do |redis|

        redis.setex 'foo', 100, 'bar'
        redis.get 'foo' do |value|
          value.should == 'bar'
          redis.ttl 'foo' do |ttl|
            ttl.should be 100
            done
          end
        end

      end
    end
  end

  describe "#setnx" do
    context "if the key already exists" do
      it "should not set the key" do
        hiredis_test do |redis|

          redis.set 'foo', 'bar'
          redis.setnx 'foo', 'baz'
          redis.get 'foo' do |value|
            value.should == 'bar'
            done
          end

        end
      end
    end

    context "if the key doesn't already exist" do
      it "should set the key" do
        hiredis_test do |redis|

          redis.setnx 'foo', 'baz'
          redis.get 'foo' do |value|
            value.should == 'baz'
            done
          end

        end
      end
    end
  end

  describe "#setrange" do
    it "overwrites a key with the given string at an offset and returns the new length" do
      hiredis_test do |redis|

        redis.set 'foo', "Vox populi, vox dei."
        redis.setrange 'foo', 16, 'canis.' do |new_length|
          new_length.should be 22
          redis.get 'foo' do |value|
            value.should == "Vox populi, vox canis."
            done
          end
        end

      end
    end
  end

  describe "#strlen" do
    it "should return the length of a string key" do
      hiredis_test do |redis|

        redis.set 'foo', 'A person who thinks all the time has nothing to think about except thoughts. So he loses touch with reality, and lives in a world of illusion.'
        redis.strlen 'foo' do |length|
          length.should be 142
          done
        end

      end
    end
  end
end
