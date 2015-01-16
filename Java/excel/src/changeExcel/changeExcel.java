package changeExcel;

import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;

import java.io.*;

public class changeExcel {
	public static void main(String[] args) {
		FileInputStream in = null;
		HSSFWorkbook wb = null;

		try {
			in = new FileInputStream("AirportDep(Raw).xls");
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
			String dest = null;
			HSSFRow r = s.getRow(i);
			if (r != null) {
				for (int j = 0; j < 13; j++) {
					HSSFCell c = r.getCell(j);
					String value = null;
					if (c == null && j == 0) {
						break;
					}
					if (c == null && j == 11) {
						boolean boolBreak = false;
						System.out.println(s.getLastRowNum());
						for (int k = 0; k < s.getLastRowNum() + 1; k++) {
							int count = 0;
							boolean boolSub = false;
							HSSFRow rr = s.getRow(k);
							if (k == i && boolBreak == true) {
								break;
							} else if (rr != null) {
								for (int l = 0; l < 13; l++) {
									HSSFCell cc = rr.getCell(l);
									if (cc != null) {
										String valueSub;
										int typeSub = cc.getCellType();
										switch (typeSub) {
										case HSSFCell.CELL_TYPE_BLANK:
											valueSub = "";
											break;

										case HSSFCell.CELL_TYPE_BOOLEAN:
											valueSub = String.valueOf(cc.getBooleanCellValue());
											break;

										case HSSFCell.CELL_TYPE_ERROR:
											valueSub = String.valueOf(cc.getErrorCellValue());
											break;

										case HSSFCell.CELL_TYPE_FORMULA:
											valueSub = String.valueOf(cc.getCellFormula());
											break;

										case HSSFCell.CELL_TYPE_NUMERIC:
											if (HSSFDateUtil.isCellDateFormatted(cc)) {
												valueSub = String.valueOf(cc.getDateCellValue());
											} else {
												valueSub = String.valueOf(cc.getNumericCellValue());
											}
											break;

										case HSSFCell.CELL_TYPE_STRING:
											valueSub = cc.getRichStringCellValue().getString();
											break;

										default:
											valueSub = cc.getRichStringCellValue().getString();
											break;
										}
										System.out.println(k + ", " + l + ": " + valueSub);

										if (!(valueSub.equals(""))) {
											if (l == 7 && !(valueSub.equals("目的地"))) {
												if (valueSub == dest) {
													boolSub = true;
												}
											} else if (l == 11 && boolSub == true) {
												value = valueSub;
												boolBreak = true;
												break;
											}
										}
									}
									count++;
								}
							}
							if (k == s.getLastRowNum() && count == 13) {
								value = "00時間00分";
							}
						}
					}
					if (c != null || value != null) {
						if (value == null) {
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
							}
							else if (j == 4 && !(value.equals("便名"))) {
								HSSFRichTextString text = new HSSFRichTextString(value);
								dest = String.valueOf(text);
								for (int k = 0; k < row.length; k++) {
									HSSFRow rr = sheet.getRow(k);
									if (rr == null) {
										rr = sheet.createRow(k);
									}
									HSSFCell cc = rr.getCell(3);
									if (cc == null) {
										cc = rr.createCell(3);
										System.out.println(text);
										cc.setCellValue(text);
										break;
									}
								}
							}
							else if (j == 7 && !(value.equals("目的地"))) {
								HSSFRichTextString text = new HSSFRichTextString(value);
								dest = String.valueOf(text);
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
							/**
							 * else if (j == 11 && !(value.equals("所要")) &&
							 * !(value.equals("時間"))) { String[] str =
							 * value.split(" ", 0); HSSFRichTextString text =
							 * new HSSFRichTextString(str[3]); for (int k = 0; k
							 * < row.length; k++) { HSSFRow rr =
							 * sheet.getRow(k); if (rr == null) { rr =
							 * sheet.createRow(k); } HSSFCell cc =
							 * rr.getCell(1); if (cc == null) { cc =
							 * rr.createCell(1); System.out.println(text);
							 * cc.setCellValue(text); break; } } }
							 **/
							else if (j == 11 && !(value.equals("所要時間"))) {
								String[] str = value.split("時間", 0);
								int h = Integer.parseInt(str[0]);
								if (str[0].charAt(0) == 0) {
									h = str[0].charAt(1);
								}
								int m = Integer.parseInt(str[1].substring(0, 2));
								if (str[1].charAt(0) == 0) {
									m = str[1].charAt(1);
								}
								String time = h + ":" + m;
								HSSFRichTextString text = new HSSFRichTextString(time);
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
						}
					}
				}
			}
		}

		FileOutputStream out = null;
		try {
			out = new FileOutputStream("AirportDep(Converted).xls");
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
