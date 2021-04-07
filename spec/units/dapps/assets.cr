# Copyright © 2017-2020 The Axentro Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the Axentro Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

require "./../../spec_helper"

include Axentro::Core
include Units::Utils
include Axentro::Core::DApps::BuildIn
include Axentro::Core::Controllers

describe AssetComponent do
  it "should perform #setup" do
    with_factory do |block_factory, _|
      component = AssetComponent.new(block_factory.add_slow_block.blockchain)
      component.setup.should be_nil
    end
  end

  it "should perform #transaction_actions" do
    with_factory do |block_factory, _|
      component = AssetComponent.new(block_factory.add_slow_block.blockchain)
      component.transaction_actions.should eq(["create_asset", "update_asset", "send_asset"])
    end
  end

  describe "#transaction_related?" do
    it "should return true when action is related" do
      DApps::ASSET_ACTIONS.each do |action|
        with_factory do |block_factory, _|
          component = AssetComponent.new(block_factory.add_slow_block.blockchain)
          component.transaction_related?(action).should be_true
        end
      end
    end
    it "should return false when action is not related" do
      with_factory do |block_factory, _|
        component = AssetComponent.new(block_factory.add_slow_block.blockchain)
        component.transaction_related?("unrelated").should be_false
      end
    end
  end

  describe "#valid_transaction?" do
    describe "common to all asset actions" do
      it "transaction -> senders must be 1" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [] of Transaction::Sender,
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("senders can only be 1 for asset action")
        end
      end

      it "transaction -> recipients must be 1" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [] of Transaction::Recipient,
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("number of specified recipients must be 1 for 'create_asset'")
        end
      end

      it "transaction -> sender and recipient must be the sender address" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          recipient_wallet = transaction_factory.recipient_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(recipient_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("address mismatch for 'create_asset'. sender: #{sender_wallet.address}, recipient: #{recipient_wallet.address}")
        end
      end

      it "transaction -> token must not be empty" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("token must not be empty")
        end
      end

      it "transaction -> amount must be 0" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet

          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 100_i64, 0_i64)],
            [a_recipient(sender_wallet, 100_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("amount must be 0 for action: create_asset")
        end
      end

      it "transaction -> fee must be 0" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 100_i64, 200_i64)],
            [a_recipient(sender_wallet, 100_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("amount must be 0 for action: create_asset")
        end
      end
    end

    describe "create_asset" do
      it "should pass when valid transaction" do
        with_factory do |block_factory, transaction_factory|
          asset_id = Asset.create_id
          transaction = transaction_factory.make_create_asset(a_quick_asset(asset_id))
          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(0)
          result.passed.should eq([transaction])
        end
      end

      it "asset -> version should be 1" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          )

          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset version must be 1 for 'create_asset'")
        end
      end

      it "asset -> asset_id must not already exist (when in same transaction batch)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction1, transaction2])
          result.passed.size.should eq(1)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset_id must not already exist (asset_id: #{asset_id}) 'create_asset'")
        end
      end

      it "asset -> asset_id must not already exist (when already in the db)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_block([transaction1]).add_slow_blocks(4)

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction2])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset_id must not already exist (asset_id: #{asset_id}) 'create_asset'")
        end
      end

      it "asset -> asset media_location must be unique and not already exist - unless empty (when in same transaction batch)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash1", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location", "media_hash2", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction1, transaction2])
          result.passed.size.should eq(1)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_location must not already exist (asset_id: #{asset_id_2}, media_location: media_location) 'create_asset'")
        end
      end

      it "asset -> asset media_location must be unique and not already exist - unless empty (when already in the db)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash1", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location", "media_hash2", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(2).add_slow_block([transaction1]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction2])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_location must not already exist (asset_id: #{asset_id_2}, media_location: media_location) 'create_asset'")
        end
      end

      it "asset -> asset_hash must be unique and not already exist - unless empty (when in same transaction batch)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location1", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location2", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(10).chain
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction1, transaction2])
          result.passed.size.should eq(1)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_hash must not already exist (asset_id: #{asset_id_2}, media_hash: media_hash) 'create_asset'")
        end
      end

      it "asset -> asset_hash must be unique and not already exist - unless empty (when already in the db)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location1", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location2", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(2).add_slow_block([transaction1]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction2])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_hash must not already exist (asset_id: #{asset_id_2}, media_hash: media_hash) 'create_asset'")
        end
      end

      it "asset -> asset media_location can be empty" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "", "media_hash1", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(0)
        end
      end

      it "asset -> asset_hash can be empty" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "", 1, "terms", 0, 1, __timestamp)]
          )

          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(0)
        end
      end
    end

    describe "create_asset and update_asset common validation" do
      it "asset must be exactly 1 asset" do
        ["create_asset", "update_asset"].each do |action|
          with_factory do |block_factory, transaction_factory|
            sender_wallet = transaction_factory.sender_wallet
            transaction = transaction_factory.make_asset(
              "AXNT",
              action,
              [a_sender(sender_wallet, 0_i64, 0_i64)],
              [a_recipient(sender_wallet, 0_i64)],
              [] of Transaction::Asset
            )
            block_factory.add_slow_blocks(10)
            component = AssetComponent.new(block_factory.blockchain)

            result = component.valid_transactions?([transaction])
            result.passed.size.should eq(0)
            result.failed.size.should eq(1)
            result.failed.first.reason.should eq("a transaction must have exactly 1 asset for '#{action}'")
          end
        end
      end

      it "asset -> asset_id must be correct length" do
        ["create_asset", "update_asset"].each do |action|
          with_factory do |block_factory, transaction_factory|
            sender_wallet = transaction_factory.sender_wallet
            transaction = transaction_factory.make_asset(
              "AXNT",
              action,
              [a_sender(sender_wallet, 0_i64, 0_i64)],
              [a_recipient(sender_wallet, 0_i64)],
              [Transaction::Asset.new("123", "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
            )
            block_factory.add_slow_blocks(10)
            component = AssetComponent.new(block_factory.blockchain)

            result = component.valid_transactions?([transaction])
            result.passed.size.should eq(0)
            result.failed.size.should eq(1)
            result.failed.first.reason.should eq("asset_id must be length of 64 for '#{action}'")
          end
        end
      end

      it "asset -> quantity must be 1 or more" do
        ["create_asset", "update_asset"].each do |action|
          with_factory do |block_factory, transaction_factory|
            sender_wallet = transaction_factory.sender_wallet
            asset_id = Transaction::Asset.create_id
            transaction = transaction_factory.make_asset(
              "AXNT",
              action,
              [a_sender(sender_wallet, 0_i64, 0_i64)],
              [a_recipient(sender_wallet, 0_i64)],
              [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 0, "terms", 0, 1, __timestamp)]
            )
            block_factory.add_slow_blocks(10)
            component = AssetComponent.new(block_factory.blockchain)

            result = component.valid_transactions?([transaction])
            result.passed.size.should eq(0)
            result.failed.size.should eq(1)
            result.failed.first.reason.should eq("asset quantity must be 1 or more for '#{action}' with asset_id: #{asset_id}")
          end
        end
      end
    end

    describe "update_asset" do
      it "should pass when valid update_asset transaction" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_block([create_transaction]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(0)
        end
      end

      it "asset must already exist" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id

          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("cannot update asset with asset_id: #{asset_id} as asset with this id is not found")
        end
      end

      it "only asset owner can update_asset" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          non_owner_wallet = Wallet.from_json(Wallet.create(true).to_json)
  
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )

          update_transaction_1 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          ) 

          update_transaction_2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "updated_description", "media_location", "media_hash", 1, "terms", 0, 3, __timestamp)]
          ) 

          block_factory.add_slow_block([create_transaction,update_transaction_1]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(non_owner_wallet, 0_i64, 0_i64)],
            [a_recipient(non_owner_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "faker", "faker", "media_location", "media_hash", 1, "terms", 0, 4, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction_2, update_transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("cannot update asset with asset_id: #{asset_id} as sender with address #{non_owner_wallet.address} does not own this asset (owned by: #{sender_wallet.address})")
        end
      end

      it "asset version should be next in sequence" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_block([create_transaction]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 0, 3, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("expected asset version 2 not 3 as next in sequence for 'update_asset'")
        end
      end

      it "media_location should not exist unless it's for the asset that is being updated (in transaction batch)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          )
          transaction3 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction1, transaction2, transaction3])
          result.passed.size.should eq(2)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_location must not already exist (asset_id: #{asset_id_2}, media_location: media_location) 'create_asset'")
        end
      end

      it "media_location should not exist unless it's for the asset that is being updated (in db)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction3 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(2).add_slow_block([transaction1, transaction2]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction3])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_location must not already exist (asset_id: #{asset_id_2}, media_location: media_location) 'create_asset'")
        end
      end

      it "media_hash should not exist unless it's for the asset that is being updated (in transaction batch)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location1", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location2", "media_hash", 1, "terms", 0, 2, __timestamp)]
          )
          transaction3 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(10)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction1, transaction2, transaction3])
          result.passed.size.should eq(2)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_hash must not already exist (asset_id: #{asset_id_2}, media_hash: media_hash) 'create_asset'")
        end
      end

      it "media_hash should not exist unless it's for the asset that is being updated (in db)" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id_1 = Transaction::Asset.create_id
          asset_id_2 = Transaction::Asset.create_id
          transaction1 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location1", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_1, "name", "description", "media_location2", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          transaction3 = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id_2, "name", "description", "media_location3", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_blocks(2).add_slow_block([transaction1, transaction2]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          result = component.valid_transactions?([transaction3])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset media_hash must not already exist (asset_id: #{asset_id_2}, media_hash: media_hash) 'create_asset'")
        end
      end

      it "cannot update asset if locked" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )

          lock_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 1, 2, __timestamp)]
          )

          block_factory.add_slow_block([create_transaction, lock_transaction]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "attempt_to_update", "description", "media_location", "media_hash", 1, "terms", 0, 3, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction])
          result.passed.size.should eq(0)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("asset is locked so no updates are possible for 'update_asset'")
        end
      end
    end

    describe "lock_asset" do
      it "should pass when valid lock_asset transaction" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )
          block_factory.add_slow_block([create_transaction]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          lock_transaction = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 1, 2, __timestamp)]
          )

          result = component.valid_transactions?([lock_transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(0)
        end
      end

      it "only asset owner can lock_asset" do
        with_factory do |block_factory, transaction_factory|
          sender_wallet = transaction_factory.sender_wallet
          non_owner_wallet = Wallet.from_json(Wallet.create(true).to_json)
  
          asset_id = Transaction::Asset.create_id

          create_transaction = transaction_factory.make_asset(
            "AXNT",
            "create_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "name", "description", "media_location", "media_hash", 1, "terms", 0, 1, __timestamp)]
          )

          update_transaction_1 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "description", "media_location", "media_hash", 1, "terms", 0, 2, __timestamp)]
          ) 

          update_transaction_2 = transaction_factory.make_asset(
            "AXNT",
            "update_asset",
            [a_sender(sender_wallet, 0_i64, 0_i64)],
            [a_recipient(sender_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "updated_name", "updated_description", "media_location", "media_hash", 1, "terms", 0, 3, __timestamp)]
          ) 

          block_factory.add_slow_block([create_transaction,update_transaction_1]).add_slow_blocks(2)
          component = AssetComponent.new(block_factory.blockchain)

          update_transaction = transaction_factory.make_asset(
            "AXNT",
            "lock_asset",
            [a_sender(non_owner_wallet, 0_i64, 0_i64)],
            [a_recipient(non_owner_wallet, 0_i64)],
            [Transaction::Asset.new(asset_id, "faker", "faker", "media_location", "media_hash", 1, "terms", 1, 4, __timestamp)]
          )

          result = component.valid_transactions?([update_transaction_2, update_transaction])
          result.passed.size.should eq(1)
          result.failed.size.should eq(1)
          result.failed.first.reason.should eq("cannot lock asset with asset_id: #{asset_id} as sender with address #{non_owner_wallet.address} does not own this asset (owned by: #{sender_wallet.address})")
        end
      end
    end
  end
end

# can only update or lock asset that is owned by sender
# can only send asset that is owned by sender