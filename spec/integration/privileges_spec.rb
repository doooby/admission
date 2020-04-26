require_relative './middle_ages'

RSpec.describe 'actions_arbitrating' do

  ORDER = MiddleAges.privileges

  it 'gets human privilege' do
    p = ORDER.get :human
    expect(p).to be_a_kind_of(Admission::Privilege)
    expect(p).to have_attributes(
        name: :human,
        level: Admission::Privilege::BASE_LEVEL_NAME,
        context: nil
    )
  end

  it 'ensures that pope inherits from priesthood' do
    p = ORDER.get :priest, :pope
    expect(p).to be_a_kind_of(Admission::Privilege)
    expect(p).to have_attributes(
        name: :priest,
        level: :pope
    )
    expect(p.eql_or_inherits? ORDER.get(:priest)).to eq(true)
  end

  it 'ensures that emperor also inherits from priesthood' do
    p = ORDER.get :emperor
    expect(p).to be_a_kind_of(Admission::Privilege)
    expect(p).to have_attributes(
        name: :emperor,
        level: Admission::Privilege::BASE_LEVEL_NAME
    )
    expect(p.eql_or_inherits? ORDER.get(:priest)).to eq(true)
  end

end
