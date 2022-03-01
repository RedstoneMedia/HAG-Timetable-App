package com.example.custom_nearby_connections

import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.nearby.connection.*;
import com.google.android.gms.nearby.Nearby;

import androidx.annotation.NonNull
import android.content.Context;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Random

private const val SERVICE_ID = "stundenplan-sds"
private val STRATEGY = Strategy.P2P_CLUSTER;

private fun generateRandomName(): String {
  var name = ""
  val random = Random()
  for (i in 0..4) {
    name += random.nextInt(10)
  }
  return name
}


class CustomNearbyConnectionsPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context : Context
  private lateinit var connectionsClient : ConnectionsClient
  private val localUserName = generateRandomName();

  internal class ReceiveBytesPayloadListener : PayloadCallback() {
    override fun onPayloadReceived(endpointId: String, payload: Payload) {
      // This always gets the full data of the payload. Is null if it's not a BYTES payload.
      if (payload.getType() === Payload.Type.BYTES) {
        val receivedBytes: ByteArray? = payload.asBytes()
      }
    }

    override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
      // Bytes payloads are sent as a single chunk, so you'll receive a SUCCESS update immediately
      // after the call to onPayloadReceived().
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "custom_nearby_connections")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  private val connectionLifecycleCallback: ConnectionLifecycleCallback = object : ConnectionLifecycleCallback() {
    override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
      // Automatically accept the connection on both sides.
      connectionsClient.acceptConnection(endpointId, ReceiveBytesPayloadListener())
      Log.i("CustomNearbyConnectionsPlugin", "Connect: $endpointId")
    }

    override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
      Log.i("CustomNearbyConnectionsPlugin", "Result: $endpointId $result")
      when (result.getStatus().getStatusCode()) {
        ConnectionsStatusCodes.STATUS_OK -> {}
        ConnectionsStatusCodes.STATUS_CONNECTION_REJECTED -> {}
        ConnectionsStatusCodes.STATUS_ERROR -> {}
        else -> {}
      }
    }

    override fun onDisconnected(endpointId: String) {
      // We've been disconnected from this endpoint. No more data can be
      // sent or received.
      Log.i("CustomNearbyConnectionsPlugin", "Disconneted: $endpointId")
    }
  }


  private val endpointDiscoveryCallback: EndpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
    override public fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
      // An endpoint was found. We request a connection to it.
      connectionsClient
              .requestConnection(localUserName, endpointId, connectionLifecycleCallback)
              .addOnSuccessListener { unused: Void? -> }
              .addOnFailureListener { e: Exception? -> }
    }

    override fun onEndpointLost(endpointId: String) {
      // A previously discovered endpoint has gone away.
      Log.i("CustomNearbyConnectionsPlugin", "Disconneted: $endpointId")
    }
  }


  fun start(@NonNull result: Result) {
    val isAvaiableResult : Int = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context);
    if (isAvaiableResult != ConnectionResult.SUCCESS) {
      result.error(isAvaiableResult.toString(), "Google play services are not available", null);
      return;
    }
    val advertisingOptions: AdvertisingOptions = AdvertisingOptions.Builder().setStrategy(STRATEGY).build()
    val discoveryOptions: DiscoveryOptions = DiscoveryOptions.Builder().setStrategy(STRATEGY).build()
    connectionsClient = Nearby.getConnectionsClient(context)
    connectionsClient.startAdvertising(localUserName, SERVICE_ID, connectionLifecycleCallback, advertisingOptions)
            .addOnSuccessListener { unused: Void? -> Log.i("CustomNearbyConnectionsPlugin", "Started Advertising")}
            .addOnFailureListener { e: Exception? -> Log.e("CustomNearbyConnectionsPlugin", e.toString())}
    connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, discoveryOptions)
            .addOnSuccessListener { unused: Void? -> Log.i("CustomNearbyConnectionsPlugin", "Started Discovery")}
            .addOnFailureListener { e: Exception? -> Log.e("CustomNearbyConnectionsPlugin", e.toString())}

    Log.i("CustomNearbyConnectionsPlugin", "Started");
    result.success(null);
  }

  fun stop() {
    Log.i("CustomNearbyConnectionsPlugin", "Stopped");
    connectionsClient.stopAdvertising();
    connectionsClient.stopDiscovery();
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "start" -> start(result)
      "stop" -> {stop(); result.success(null)}
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    stop();
    channel.setMethodCallHandler(null)
  }
}
