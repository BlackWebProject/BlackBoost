package com.blackboost.app

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.*

/** Разовая покупка Premium через Google Play Billing. ID товара создайте в Play Console. */
class Billing(c: Context, private val onPremium: () -> Unit) : PurchasesUpdatedListener {
    companion object { const val ID = "premium_forever" }
    private val client = BillingClient.newBuilder(c).setListener(this).enablePendingPurchases().build()
    private var details: ProductDetails? = null
    var price by mutableStateOf<String?>(null)

    fun start() {
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(r: BillingResult) {
                if (r.responseCode == BillingClient.BillingResponseCode.OK) { query(); restore() }
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun query() {
        val p = QueryProductDetailsParams.newBuilder().setProductList(
            listOf(QueryProductDetailsParams.Product.newBuilder().setProductId(ID).setProductType(BillingClient.ProductType.INAPP).build())
        ).build()
        client.queryProductDetailsAsync(p) { _, list ->
            details = list.firstOrNull()
            price = details?.oneTimePurchaseOfferDetails?.formattedPrice
        }
    }

    fun restore() {
        if (!client.isReady) { start(); return }
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { _, l -> handle(l) }
    }

    fun buy(a: Activity): Boolean {
        val d = details ?: return false
        val pd = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).build()
        client.launchBillingFlow(a, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(pd)).build())
        return true
    }

    override fun onPurchasesUpdated(r: BillingResult, l: MutableList<Purchase>?) {
        if (r.responseCode == BillingClient.BillingResponseCode.OK && l != null) handle(l)
    }

    private fun handle(l: List<Purchase>) {
        for (p in l) {
            if (p.products.contains(ID) && p.purchaseState == Purchase.PurchaseState.PURCHASED) {
                if (!p.isAcknowledged) client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build()) {}
                onPremium()
            }
        }
    }
}
