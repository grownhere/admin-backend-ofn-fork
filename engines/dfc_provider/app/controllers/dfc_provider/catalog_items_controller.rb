# frozen_string_literal: true

# Controller used to provide the API products for the DFC application
# CatalogItems are items that are being sold by the entreprise.
module DfcProvider
  class CatalogItemsController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def index
      person = PersonBuilder.person(current_user)

      enterprises = current_user.enterprises.map do |enterprise|
        EnterpriseBuilder.enterprise(enterprise)
      end
      person.affiliatedOrganizations = enterprises
      catalog_items = enterprises.flat_map(&:catalogItems)

      render json: DfcIo.export(
        person,
        *enterprises,
        *catalog_items,
        *catalog_items.map(&:product),
        *catalog_items.map(&:product).flat_map(&:isVariantOf),
        *catalog_items.flat_map(&:offers),
      )
    end

    def show
      catalog_item = DfcBuilder.catalog_item(variant)
      offers = catalog_item.offers
      render json: DfcIo.export(catalog_item, *offers)
    end

    def update
      dfc_request = JSON.parse(request.body.read)

      variant.on_hand = dfc_request["dfc-b:stockLimitation"]
      variant.sku = dfc_request["dfc-b:sku"]
      variant.save!
    end

    private

    def variant
      @variant ||= current_enterprise.supplied_variants.find(params[:id])
    end
  end
end
