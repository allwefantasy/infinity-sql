package tech.mlsql.datasource.helper

import org.apache.hadoop.fs.{FileSystem, Path}
import tech.mlsql.common.utils.cache.{CacheBuilder, RemovalListener, RemovalNotification}
import tech.mlsql.common.utils.log.Logging
import tech.mlsql.tool.HDFSOperatorV2

import java.util
import java.util.concurrent.TimeUnit
import scala.collection.JavaConverters._

object MLSQLRestCache extends Logging {
  val cacheFiles = CacheBuilder.newBuilder().
    maximumSize(100000).removalListener(new RemovalListener[String, java.util.List[String]]() {
      override def onRemoval(notification: RemovalNotification[String, util.List[String]]): Unit = {
        val files = notification.getValue
        if (files != null) {
          val fs = FileSystem.get(HDFSOperatorV2.hadoopConfiguration)
          files.asScala.foreach { file =>
            try {
              logInfo(s"remove cache file ${file}")
              fs.delete(new Path(file), true)
            } catch {
              case e: Exception =>
                logError(s"remove cache file ${file} failed", e)
            }
          }
        }
      }
    }).
    expireAfterWrite(1, TimeUnit.DAYS).
    build[String, java.util.List[String]]()
}
