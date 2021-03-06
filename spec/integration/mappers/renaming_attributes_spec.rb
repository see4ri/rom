require 'spec_helper'
require 'rom/memory'

describe 'Mappers / Renaming attributes' do
  let(:setup) { ROM.setup(:memory) }

  before do
    setup.relation(:addresses)

    setup.relation(:users) do
      def with_address
        join(addresses)
      end

      def with_addresses
        join(addresses)
      end
    end
  end

  it 'maps renamed attributes for a base relation' do
    setup.mappers do
      define(:users) do
        model name: 'Test::User'

        attribute :id, from: :_id
        attribute :name, from: :user_name
      end
    end

    rom = setup.finalize

    Test::User.send(:include, Equalizer.new(:id, :name))

    rom.relations.users << { _id: 123, user_name: 'Jane' }

    jane = rom.relation(:users).as(:users).first

    expect(jane).to eql(Test::User.new(id: 123, name: 'Jane'))
  end

  it 'maps renamed attributes for a wrapped relation' do
    setup.mappers do
      define(:users) do
        model name: 'Test::User'

        attribute :id, from: :_id
        attribute :name, from: :user_name
      end

      define(:with_address, parent: :users) do
        model name: 'Test::UserWithAddress'

        attribute :id, from: :_id
        attribute :name, from: :user_name

        wrap :address do
          attribute :id, from: :address_id
          attribute :street, from: :address_street
        end
      end
    end

    rom = setup.finalize

    Test::UserWithAddress.send(:include, Equalizer.new(:id, :name, :address))

    rom.relations.users << { _id: 123, user_name: 'Jane' }

    rom.relations.addresses <<
      { _id: 123, address_id: 321, address_street: 'Street 1' }

    jane = rom.relation(:users).with_address.as(:with_address).first

    expect(jane).to eql(
      Test::UserWithAddress.new(id: 123, name: 'Jane',
                                address: { id: 321, street: 'Street 1' })
    )
  end

  it 'maps renamed attributes for a grouped relation' do
    setup.mappers do
      define(:users) do
        model name: 'Test::User'

        attribute :id, from: :_id
        attribute :name, from: :user_name
      end

      define(:with_addresses, parent: :users) do
        model name: 'Test::UserWithAddresses'

        attribute :id, from: :_id
        attribute :name, from: :user_name

        group :addresses do
          attribute :id, from: :address_id
          attribute :street, from: :address_street
        end
      end
    end

    rom = setup.finalize

    Test::UserWithAddresses.send(:include, Equalizer.new(:id, :name, :addresses))

    rom.relations.users << { _id: 123, user_name: 'Jane' }

    rom.relations.addresses <<
      { _id: 123, address_id: 321, address_street: 'Street 1' }
    rom.relations.addresses <<
      { _id: 123, address_id: 654, address_street: 'Street 2' }

    jane = rom.relation(:users).with_addresses.as(:with_addresses).first

    expect(jane).to eql(
      Test::UserWithAddresses.new(
        id: 123,
        name: 'Jane',
        addresses: [{ id: 321, street: 'Street 1' },
                    { id: 654, street: 'Street 2' }]
      )
    )
  end
end
