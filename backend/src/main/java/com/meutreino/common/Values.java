package com.meutreino.common;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;

/** Conversores para os resultados de queries nativas. */
public final class Values {

    private Values() {
    }

    public static Long toLong(Object value) {
        return value == null ? null : ((Number) value).longValue();
    }

    public static Integer toInteger(Object value) {
        return value == null ? null : ((Number) value).intValue();
    }

    public static BigDecimal toBigDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof BigDecimal decimal) {
            return decimal;
        }
        return BigDecimal.valueOf(((Number) value).doubleValue());
    }

    public static Instant toInstant(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Instant instant) {
            return instant;
        }
        if (value instanceof Timestamp timestamp) {
            return timestamp.toInstant();
        }
        if (value instanceof OffsetDateTime offset) {
            return offset.toInstant();
        }
        if (value instanceof java.time.LocalDateTime localDateTime) {
            return localDateTime.atZone(java.time.ZoneId.systemDefault()).toInstant();
        }
        return null;
    }

    public static LocalDate toLocalDate(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof LocalDate localDate) {
            return localDate;
        }
        if (value instanceof java.sql.Date date) {
            return date.toLocalDate();
        }
        Instant instant = toInstant(value);
        return instant == null ? null : LocalDate.ofInstant(instant, java.time.ZoneId.systemDefault());
    }
}
