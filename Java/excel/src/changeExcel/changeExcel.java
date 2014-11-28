package changeExcel;

import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;

import java.io.*;

public class changeExcel {
	public static void main(String[] args) {
		FileInputStream in = null;
		HSSFWorkbook wb = null;

		try {
			in = new FileInputStream("Narita_International_Airport_flightall(departure).xls");
			wb = (HSSFWorkbook) WorkbookFactory.create(in);
		} catch (IOException e) {
			System.out.println(e.toString());
		} catch (InvalidFormatException e) {
			System.out.println(e.toString());
		} finally {
			try {
				in.close();
			} catch (IOException e) {
				System.out.println(e.toString());
			}
		}

		HSSFSheet s = wb.getSheetAt(0);

		HSSFWorkbook workbook = new HSSFWorkbook();
		HSSFSheet sheet = workbook.createSheet();
		HSSFRow[] row = new HSSFRow[s.getLastRowNum() + 1];
		HSSFCell[] cell = new HSSFCell[3];

		System.out.println(s.getLastRowNum());
		for (int i = 0; i < s.getLastRowNum() + 1; i++) {
			HSSFRow r = s.getRow(i);
			if (r != null) {
				for (int j = 0; j < 13; j++) {
					HSSFCell c = r.getCell(j);
					if (c != null) {
						String value;
						int type = c.getCellType();
						switch (type) {
						case HSSFCell.CELL_TYPE_BLANK:
							value = "";
							break;

						case HSSFCell.CELL_TYPE_BOOLEAN:
							value = String.valueOf(c.getBooleanCellValue());
							break;

						case HSSFCell.CELL_TYPE_ERROR:
							value = String.valueOf(c.getErrorCellValue());
							break;

						case HSSFCell.CELL_TYPE_FORMULA:
							value = String.valueOf(c.getCellFormula());
							break;

						case HSSFCell.CELL_TYPE_NUMERIC:
							if (HSSFDateUtil.isCellDateFormatted(c)) {
								value = String.valueOf(c.getDateCellValue());
							} else {
								value = String.valueOf(c.getNumericCellValue());
							}
							break;

						case HSSFCell.CELL_TYPE_STRING:
							value = c.getRichStringCellValue().getString();
							break;

						default:
							value = c.getRichStringCellValue().getString();
							break;
						}
						System.out.println(i + ", " + j + ": " + value);

						if (!(value.equals(""))) {
							if (j == 0 && !(value.equals("定刻"))) {
								String[] str = value.split(" ", 0);
								HSSFRichTextString text = new HSSFRichTextString(str[3]);
								for (int k = 0; k < row.length; k++) {
									HSSFRow rr = sheet.getRow(k);
									if (rr == null) {
										rr = sheet.createRow(k);
									}
									HSSFCell cc = rr.getCell(0);
									if (cc == null) {
										cc = rr.createCell(0);
										System.out.println(text);
										cc.setCellValue(text);
										break;
									}
								}
							} else if (j == 11 && !(value.equals("所要"))
									&& !(value.equals("時間"))) {
								String[] str = value.split(" ", 0);
								HSSFRichTextString text = new HSSFRichTextString(str[3]);
								for (int k = 0; k < row.length; k++) {
									HSSFRow rr = sheet.getRow(k);
									if (rr == null) {
										rr = sheet.createRow(k);
									}
									HSSFCell cc = rr.getCell(1);
									if (cc == null) {
										cc = rr.createCell(1);
										System.out.println(text);
										cc.setCellValue(text);
										break;
									}
								}
							} 
							/**else if (j == 11 && !(value.equals("所要時間"))) {
								String[] str = value.split("時間", 0);
								int h = Integer.parseInt(str[0]);
								if (str[0].charAt(0) == 0) {
									h = str[0].charAt(1);
								}
								int m = Integer
										.parseInt(str[1].substring(0, 2));
								if (str[1].charAt(0) == 0) {
									m = str[1].charAt(1);
								}
								String time = h + ":" + m;
								HSSFRichTextString text = new HSSFRichTextString(
										time);
								for (int k = 0; k < row.length; k++) {
									HSSFRow rr = sheet.getRow(k);
									if (rr == null) {
										rr = sheet.createRow(k);
									}
									HSSFCell cc = rr.getCell(1);
									if (cc == null) {
										cc = rr.createCell(1);
										System.out.println(text);
										cc.setCellValue(text);
										break;
									}
								}
							}**/ 
							else if (j == 7 && !(value.equals("目的地"))) {
								HSSFRichTextString text = new HSSFRichTextString(value);
								for (int k = 0; k < row.length; k++) {
									HSSFRow rr = sheet.getRow(k);
									if (rr == null) {
										rr = sheet.createRow(k);
									}
									HSSFCell cc = rr.getCell(2);
									if (cc == null) {
										cc = rr.createCell(2);
										System.out.println(text);
										cc.setCellValue(text);
										break;
									}
								}
							}
						}
					}
				}
			}
		}

		FileOutputStream out = null;
		try {
			out = new FileOutputStream("Narita_International_Airport_flightall(departure)_1.xls");
			workbook.write(out);
		} catch (IOException e) {
			System.out.println(e.toString());
		} finally {
			try {
				out.close();
			} catch (IOException e) {
				System.out.println(e.toString());
			}
		}

	}
}
