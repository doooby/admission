require 'test_helper'

class UserStatusTest < ActiveSupport::TestCase

  test 'privileges order not changed' do
    privs = UserStatus.privileges_list
    assert_equal [Admission::Privilege], privs.map(&:class).uniq
    assert_equal %w[
      duke
      human
      human-adult
      human-adult_white_male
      lord
    ], privs.map(&:text_key).sort
  end

  test '#dump_privileges' do
    privs = UserStatus.privileges_list.sort_by(&:text_key)
    privs = privs.each_with_index.map{|p, i| p.dup_with_context (i % 3).to_s}
    hash = UserStatus.dump_privileges privs
    expected_hash = {
        "0"=> %w[duke human-adult_white_male],
        "1"=> %w[human lord],
        "2"=> %w[human-adult],
        "_all"=> %w[duke human human-adult human-adult_white_male lord]
    }
    assert_equal expected_hash, hash
  end

  test '#parse_privileges' do
    privs = {
        "Bohemia"=> %w[duke human-adult_white_male],
        "_all"=> %w[duke human-adult_white_male]
    }
    privs = UserStatus.parse_privileges privs
    assert_equal 2, privs.length
    duke, adult = privs.partition{|p| p.text_key == 'duke'}.map(&:first)

    assert_not_nil duke
    assert_equal :duke, duke.name
    assert_equal :base, duke.level
    assert_equal 'Bohemia', duke.context

    assert_not_nil adult
    assert_equal :human, adult.name
    assert_equal :adult_white_male, adult.level
    assert_equal 'Bohemia', adult.context
  end

end